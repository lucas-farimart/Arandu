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
print("    _                    _        _   __  __ _  _ ___ ___ _____   _____       _   ")
print("   /_\  _ _ __ _ _ _  __| |_  _  (_) |  \/  | \| |_ _/ __|_   _| |_   _|__ __| |_ ")
print("  / _ \| '_/ _` | ' \/ _` | || |  _  | |\/| | .` || |\__ \ | |     | |/ -_|_-<  _|")
print(" /_/ \_\_| \__,_|_||_\__,_|\_,_| (_) |_|  |_|_|\_|___|___/ |_|     |_|\___/__/\__|")                                                                             
print()                                                                        
                                                                               
#=================================================
# DATASET MNIST
#=================================================

(x_train, y_train), _ = tf.keras.datasets.mnist.load_data()

x_train = x_train.astype(np.float32) / 255.0   # normaliza
x_train = x_train.reshape(-1, 784)             # flatten: 28x28 -> 784

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

print("\n============================================================")
print("                         MODEL REPORT                         ")
print("============================================================\n")
model.summary() # resumo completo
print("------------------------------------------------------------")
print(f"Numero de camadas : {len(model.layers)}")
print(f"Total de parametros: {model.count_params()}")
print(f"Input shape        : {model.input_shape}")
print(f"Output shape       : {model.output_shape}")
print("============================================================\n")

#=================================================
# EXTRAI PRIMEIRA CAMADA
#=================================================

print()

W, bias = model.layers[0].get_weights()
print("Original W shape:", W.shape)

# transpose:
# Tensorflow dense  = (784,512)
# Arandu's pipeline = (512,784)

Wq = np.round(W.T * 127).astype(np.int8) 
xq = np.round(x_train[0] * 127).astype(np.int8)

#=================================================
# PIPELINE EM BLOCOS
#=================================================

pilha = []
batch_size = 4
block_views = 5
shift = 8

for i in range(0, len(Wq), batch_size):

    bloco_w = Wq[i:i+batch_size]
    faltando = batch_size - len(bloco_w)

    if faltando > 0:
        bloco_w = np.pad(
            bloco_w,
            ((0, faltando), (0, 0)),
            mode='constant'
        )

    # MAC + requantização 
    y_bloco = bloco_w.astype(np.int32) @ xq.astype(np.int32)
    y_bloco = (y_bloco + (1 << (shift - 1))) >> shift
    y_bloco = y_bloco.astype(np.int16)

    pilha.append(y_bloco)
    # if ( i < block_views * batch_size):
    #     print()
    #     print(f"Stack on Write {i//batch_size}:")
    #     print(np.vectorize(lambda v: hex(v & 0xFF))(np.array(pilha)[::-1]))
    #     print()

#=================================================
# SAÍDA FINAL
#=================================================

y_final = np.concatenate(pilha)

print("Final output shape:", y_final.shape)
print("Stack shape:",np.array(pilha).shape)
print()
