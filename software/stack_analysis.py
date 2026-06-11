#==========================================================================
# Teste de stack buffers 
#--------------------------------------------------------------------------
# Autor: Lucas Farias Martis
# Email: lucas.martins@ee.ufcg.edu.br
# Data: 2026-05-21
# Uso de LLMs: sim
#==========================================================================

import numpy as np

x = np.random.randint(-127, 128, size=784)
print("\n X SHAPE:",x.shape)

w = np.random.randint(-127, 128, size=(512, 784))
print("\n W SHAPE:",w.shape)

pilha = []
batch_size = 4
block_views = 5
shift = 8

for i in range(0, len(w), batch_size):

    bloco_w = w[i:i+batch_size]
    remain  = batch_size - len(bloco_w)

    if remain > 0:
        bloco_w = np.pad(
            bloco_w,
            ((0, remain), (0, 0)),
            mode='constant'
        )

    #=================================================
    # MAC (produto interno)
    #=================================================
    y_bloco = bloco_w @ x 
    if ( i < block_views * batch_size):
        print()
        print("Bloco pré requantização:")
        print("[DEC] -> ",y_bloco)
        print("[HEX] -> ",[hex(v & 0xFFFF) for v in y_bloco])

    #=================================================
    # REQUANTIZAÇÃO: segunda é mais hardware
    #=================================================
    # y_bloco = np.round(y_bloco / (2 ** shift))
    y_bloco = (y_bloco + (1 << (shift - 1))) >> shift
    if ( i < block_views * batch_size):
        print()
        print("Bloco pós requantização:")
        print("[DEC] -> ",y_bloco)
        print("[HEX] -> ",[hex(v & 0xFFFF) for v in y_bloco])
        print()

    #=================================================
    # Converte para inteiro
    #=================================================
    y_bloco = y_bloco.astype(np.int16)
    pilha.append(y_bloco) # salva

    if ( i < block_views * batch_size):
        print(30*"-")
        print(f"Stack on Write {i//batch_size}:")
        print(np.array(pilha)[::-1])
        print(30*"-")
        print()



# junta tudo
y_final = np.concatenate(pilha)

print("Shape final:", y_final.shape)
print("Stack final:", np.array(pilha).shape)