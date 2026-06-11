#==========================================================================
# Teste de stack buffers com Tensorflow e Modelo pequeno treinado
# para o MNIST
#--------------------------------------------------------------------------
# Autor: Lucas Farias Martis
# Email: lucas.martins@ee.ufcg.edu.br
# Data: 2026-05-21
# Uso de LLMs: sim
#==========================================================================

import numpy as np
import tensorflow as tf

print()                                                                           
print("  ___ _         _   _      _   __  __ _  _ ___ ___ _____   _____       _   ")
print(" | __| |__ _ __| |_(_)__  (_) |  \/  | \| |_ _/ __|_   _| |_   _|__ __| |_ ")
print(" | _|| / _` (_-<  _| / _|  _  | |\/| | .` || |\__ \ | |     | |/ -_|_-<  _|")
print(" |___|_\__,_/__/\__|_\__| (_) |_|  |_|_|\_|___|___/ |_|     |_|\___/__/\__|")
print()                                                                        

#=================================================
# DATASET MNIST
#=================================================

(x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()

x_train = x_train.astype(np.float32) / 255.0   # normaliza
x_train = x_train.reshape(-1, 784)             # flatten: 28x28 -> 784

x_test  = x_test.astype(np.float32) / 255.0   
x_test  = x_test.reshape(-1, 784)             

#=================================================
# MODELO
#=================================================

model = tf.keras.Sequential([
    tf.keras.layers.Dense(512,activation='relu',input_shape=(784,)),
    tf.keras.layers.Dense(10)
])

#=================================================
# COMPILA e TREINA 5 EPOCAS
#=================================================

model.compile(
    optimizer='adam',
    loss=tf.keras.losses.SparseCategoricalCrossentropy(
        from_logits=True
    ),
    metrics=['accuracy']
)

model.fit(x_train,y_train,epochs=5,batch_size=128)

#==================================================
# RELATÓRIO DO MODELO
#==================================================

print()
print("===============================================================================")
print("                                  MODEL REPORT                                 ")
print("===============================================================================")
model.summary() # resumo completo
# print("-------------------------------------------------------------------------------")
# print(f"Numero de camadas : {len(model.layers)}")
# print(f"Total de parametros: {model.count_params()}")
# print(f"Input shape        : {model.input_shape}")
# print(f"Output shape       : {model.output_shape}")
print("===============================================================================")
print()

#=================================================
#         ____________________________
#        |____ PROPOSING DATAFLOW ____|
#=================================================

W1, b1 = model.layers[0].get_weights()
W2, b2 = model.layers[1].get_weights()

W1q = np.round(W1.T * 127).astype(np.int8) 
W2q = np.round(W2.T * 127).astype(np.int8) 

print("\nW1 and W2 post-quantized")
print("Transposed W1 shape:", W1q.shape)
print("Transposed W2 shape:", W2q.shape)

acertos = 0
for b in range(100):

    xq = np.round(x_test[b] * 127).astype(np.int8)

    #--------------------------------------
    # FIRST ACTIVATIONS
    #--------------------------------------
    actv1 = np.array([], dtype=np.int32)
    fsum = 0

    for i in range(512):
        fsum = 0
        for j in range(784):
            fsum += W1q[i][j] * xq[j]
        actv1 = np.append(actv1, max(0,fsum))

    # actv1 = np.round(actv1 * 127).astype(np.int8)
    actv1 = np.clip(actv1 / 4096, -128, 127).astype(np.int8)

    #--------------------------------------
    # SECOND ACTIVATIONS
    #--------------------------------------
    actv2 = np.array([], dtype=np.int32)

    for i in range(10):
        fsum = 0
        for j in range(512):
            fsum += W2q[i][j] * actv1[j]
        actv2 = np.append(actv2, fsum)

    # actv2 = np.round(actv2 * 127).astype(np.int8) 
    # actv2 = np.clip(actv2 / 4096, -128, 127).astype(np.int8)

    #--------------------------------------
    # SOFTMAX
    #--------------------------------------
    logits     = actv2.astype(np.float32)
    logits     = logits - np.max(logits)
    exp_logits = np.exp(logits)
    softmax    = exp_logits / np.sum(exp_logits)
    # print("Softmax:", softmax)

    pred = np.argmax(softmax)
    # print("Predicted label:", pred,"| Input label:",y_test[b],"|")

    if ( b%10 == 0 ):
        print(f"tests {b}/100")

    if (pred == y_test[b]):
        acertos += 1

    # end of loop

print("\n=====================================")
print("Numero de acertos:", acertos)
print("Percnt de acertos:", 100*acertos/100)
print()