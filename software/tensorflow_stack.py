#==========================================================================
# Teste de stack buffers com o tensorflow
#--------------------------------------------------------------------------
# Autor: Lucas Farias Martis
# Email: lucas.martins@ee.ufcg.edu.br
# Data: 2026-05-21
# Uso de LLMs: sim
#==========================================================================

import numpy as np
import tensorflow as tf

#=========================================================
# MODELO
#=========================================================

model = tf.keras.Sequential([
    tf.keras.layers.Dense(512, input_shape=(784,))
])

model.build()

#=========================================================
# EXTRAI PRIMEIRA CAMADA
#=========================================================
W, bias = model.layers[0].get_weights()
W = W.T  # transpose para formato do seu pipeline
W = np.round(W * 127).astype(np.int16) # quantiza pesos para int16

#=========================================================
# ENTRADA
#=========================================================

x = np.random.randint(-127, 128, size=784, dtype=np.int16)

#=========================================================
# PROCESSAMENTO EM BLOCOS
#=========================================================

pilha = []
batch_size = 4
block_views = 5
shift = 8

for i in range(0, len(W), batch_size):

    bloco_w = W[i:i+batch_size]

    faltando = batch_size - len(bloco_w)

    if faltando > 0:
        bloco_w = np.pad(
            bloco_w,
            ((0, faltando), (0, 0)),
            mode='constant'
        )

    y_bloco = bloco_w @ x
    if ( i < block_views * batch_size):
        print()
        print("Bloco pré requantização:",y_bloco)

    y_bloco = (y_bloco + (1 << (shift - 1))) >> shift
    if ( i < block_views * batch_size):
        print("Bloco pós requantização:",y_bloco)

    y_bloco = y_bloco.astype(np.int16)
    pilha.append(y_bloco)
    if ( i < block_views * batch_size):
        print()

        print(f"Stack on Write {i//batch_size}:")
        print(np.vectorize(lambda v: hex(v & 0xFF))(np.array(pilha)[::-1]))
        print()


#=========================================================
# SAÍDA FINAL
#=========================================================

y_final = np.concatenate(pilha)

print("Final shape:", y_final.shape)
print("Stack shape:", np.array(pilha).shape)
print()