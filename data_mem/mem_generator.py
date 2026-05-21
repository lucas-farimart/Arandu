#============================================================
# Exportador .MEM Completo de Rede Neural TensorFlow
#------------------------------------------------------------
#    Modelo:
#      784 -> Dense(128) -> Dense(10)
#    Recursos:
#    - Exporta TODAS as camadas
#    - Exporta pesos e bias
#    - Quantizacao INT8
#    - Organizacao em palavras de 32 bits
#    - Estatísticas completas de memoria
#------------------------------------------------------------
# Autor: Lucas Faris Martins
# Email: lucas.martins@ee.ufcg.edu.br
# Data: 2026-05-15
#============================================================

import os
# os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
import tensorflow as tf
import numpy as np

print("[INFO] Libraries Imported")

#============================================================
# CONFIGURAÇOES
#============================================================
ENDIAN = "little"

def int2byte(valor):
    return valor & 0xFF

def bytes2word(dados_bytes,endian="little"):

    dados_bytes.append(0)
    palavras = []

    for i in range(0, len(dados_bytes), 4):
        b0, b1, b2, b3 = dados_bytes[i:i+4]
        if endian == "little":
            palavra = (
                b0
                | (b1 << 8)
                | (b2 << 16)
                | (b3 << 24)
            )
        else:

            palavra = (
                (b0 << 24)
                | (b1 << 16)
                | (b2 << 8)
                | b3
            )
        palavras.append(palavra)
    return palavras

print("[INFO] int2byte and byte2word Built")

#============================================================
# MEM
#============================================================

def exportar_mem(nome, palavras):
    with open(nome, "w") as f:
        for p in palavras:
            f.write(f"{p:08X}\n")
    print(f"Arquivo exportado: {nome}")

print("[INFO] Memory export ready")

#============================================================
# INT8
#============================================================

def quantizar_tensor(tensor):

    max_abs = np.max(np.abs(tensor))

    if max_abs == 0:
        escala = 1.0
    else:
        escala = 127.0 / max_abs

    tensor_q = np.round(
        tensor * escala
    ).astype(np.int8)

    return tensor_q

print("[INFO] Tensor quantization ready")

#============================================================
# MODELO
#============================================================

(x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
x_train = x_train.reshape(-1, 784).astype("float32") / 255.0
x_test  = x_test.reshape(-1, 784).astype("float32") / 255.0
num_classes = 10

model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(784,)),
    tf.keras.layers.Dense(
        128,
        activation="relu",
        name="dense_1"
    ),
    tf.keras.layers.Dense(
        10,
        activation="softmax",
        name="dense_2"
    )
])

model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

print("\n"); print(60*"=")
print("[INFO] Treinando modelo...")
model.fit(x_train, y_train, epochs=5, batch_size=64, verbose=2)
print(" VALIDACAO DO MODELO: ")
loss, acc = model.evaluate(x_test, y_test, verbose=0)
print(f"[INFO] Acuracia do Test: {100*acc:.2f}")
print(60*"="); print("\n")

#============================================================
# INICIALIZACAO
#============================================================
dummy_input = np.zeros((1, 784),dtype=np.float32)
model(dummy_input)

#============================================================
# ENTRADA EXEMPLO
#============================================================
entrada = np.random.randint(0,256,size=(784,),dtype=np.uint8)
print("Entrada:", entrada,"\n")
print("Shape: {entrada.shape}")
entrada_bytes = [int(v) for v in entrada ]
print("Entrada em bytes:", entrada_bytes,"\n")
print("Shape: {entrada.shape}")
input_32b = bytes2word(entrada_bytes,ENDIAN)
exportar_mem("entrada.mem",input_32b)

#============================================================
# MOSTRA ENTRADA
#============================================================

print("\n===================================================")
print("VETOR DE ENTRADA")
print("===================================================")

print(f"Shape: {entrada.shape}")

print("\nPrimeiros 32 valores:")

print(entrada[:32])


#============================================================
# ESTATÍSTICAS GLOBAIS
#============================================================

total_bytes = len(entrada_bytes)


#============================================================
# PROCESSAMENTO DAS CAMADAS
#============================================================

for layer in model.layers:

    # Ignora camadas sem pesos
    if len(layer.get_weights()) == 0:
        continue

    print("\n===================================================")
    print(f"PROCESSANDO CAMADA: {layer.name}")
    print("===================================================")

    pesos, bias = layer.get_weights()

    #========================================================
    #    #========================================================

    pesos_q = quantizar_tensor(pesos)

    bias_q = quantizar_tensor(bias)


    #========================================================
    #    #========================================================

    print(f"\nShape dos pesos: {pesos_q.shape}")
    print(f"Shape do bias : {bias_q.shape}")

    print("\nAmostra dos pesos:")

    linhas = min(4, pesos_q.shape[0])
    colunas = min(8, pesos_q.shape[1])

    print(
        pesos_q[:linhas, :colunas]
    )

    print("\nPrimeiros bias:")

    print(
        bias_q[:min(16, len(bias_q))]
    )


    #========================================================
    # CONVERSÃO PARA BYTES
    #========================================================

    pesos_bytes = []

    for linha in pesos_q:

        for v in linha:

            pesos_bytes.append(
                int2byte(int(v))
            )

    bias_bytes = []

    for v in bias_q:

        bias_bytes.append(
            int2byte(int(v))
        )


    #========================================================
    # 32 BITS
    #========================================================

    pesos_32b = bytes2word(
        pesos_bytes,
        ENDIAN
    )

    bias_32b = bytes2word(
        bias_bytes,
        ENDIAN
    )


    #========================================================
    #    #========================================================

    nome_pesos = f"{layer.name}_pesos.mem"

    nome_bias = f"{layer.name}_bias.mem"

    exportar_mem(
        nome_pesos,
        pesos_32b
    )

    exportar_mem(
        nome_bias,
        bias_32b
    )


    #========================================================
    # ESTATÍSTICAS
    #========================================================

    bytes_pesos = len(pesos_bytes)

    bytes_bias = len(bias_bytes)

    total_layer = (
        bytes_pesos +
        bytes_bias
    )

    total_bytes += total_layer


    print("\nESTATÍSTICAS DA CAMADA")

    print(
        f"Pesos : "
        f"{bytes_pesos} bytes "
        f"({bytes_pesos / 1024:.2f} KB)"
    )

    print(
        f"Bias  : "
        f"{bytes_bias} bytes "
        f"({bytes_bias / 1024:.2f} KB)"
    )

    print(
        f"Total : "
        f"{total_layer} bytes "
        f"({total_layer / 1024:.2f} KB)"
    )


    #========================================================
    # EXEMPLO DAS PALAVRAS
    #========================================================

    print("\nPrimeiras palavras dos pesos:")

    for i in range(min(8, len(pesos_32b))):

        print(
            f"Word {i}: "
            f"0x{pesos_32b[i]:08X}"
        )

    print("\nPrimeiras palavras do bias:")

    for i in range(min(4, len(bias_32b))):

        print(
            f"Word {i}: "
            f"0x{bias_32b[i]:08X}"
        )


#============================================================
# TOTAL GERAL
#============================================================

print("\n===================================================")
print("ESTATÍSTICAS GERAIS")
print("===================================================")

print(
    f"Bytes totais efetivos : "
    f"{total_bytes}"
)

print(
    f"Tamanho total em KB   : "
    f"{total_bytes / 1024:.2f} KB"
)

print("\nArquivos .mem gerados com sucesso.")

print("\nProcesso concluído.")