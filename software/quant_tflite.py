#==========================================================================
# Treinamento de rede e Pos-quantizacao
#-------------------------------------------------------------------------
# Autor: Lucas Farias Martis
# Email: lucas.martins@ee.ufcg.edu.br
# Data: 2026-05-18
# Uso de LLMs: sim
#==========================================================================

import tensorflow as tf
import tensorflow_model_optimization as tfmot
from tensorflow.keras import layers, models, optimizers

#------------------------------------------------------------------
#    Configura política mixed_precision (FP16) 
#------------------------------------------------------------------
policy = tf.keras.mixed_precision.Policy('mixed_float16')
tf.keras.mixed_precision.set_global_policy(policy)

#------------------------------------------------------------------
#    Define um modelo simples 
#------------------------------------------------------------------
model = models.Sequential([
    layers.Conv2D(32, 3, activation='relu', input_shape=(28, 28, 1)),
    layers.MaxPooling2D(),
    layers.Conv2D(64, 3, activation='relu'),
    layers.MaxPooling2D(),
    layers.Flatten(),
    layers.Dense(128, activation='relu'),
    layers.Dense(10, activation='softmax')
])

# Compila com otimizador loss scaling (a ser convertido em LossScaleOptimizer)
opt = optimizers.Adam(learning_rate=1e-3)
model.compile(optimizer=opt,
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

# ------------------------------------------------------------------
#     Dados de exemplo (MNIST) 
# ------------------------------------------------------------------
(x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
x_train = x_train[..., None] / 255.0
x_test  = x_test[..., None]  / 255.0

train_ds = tf.data.Dataset.from_tensor_slices((x_train, y_train)).shuffle(10000).batch(128)
test_ds  = tf.data.Dataset.from_tensor_slices((x_test, y_test)).batch(128)

#------------------------------------------------------------------
#    Treina 
#------------------------------------------------------------------
model.fit(train_ds, epochs=5, validation_data=test_ds)

#------------------------------------------------------------------
#    Salva modelo (FP32 nos pesos) 
#------------------------------------------------------------------
model.save('models/my_model_fp32.h5')   # pesos são armazenados em FP32 mesmo com FP16

#------------------------------------------------------------------
#    Converte para TFLite com quantização int8 
#------------------------------------------------------------------
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]   # ativa quantização post‑training
tflite_quant = converter.convert()

with open('my_model_int8.tflite', 'wb') as f:
    f.write(tflite_quant)

print(' Treinamento concluído. Modelo salvo em FP32 e TFLite int8.')