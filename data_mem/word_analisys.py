#==========================================================================
# Descricao: Estudo de armazenamento de matrizes NxM de elementos 8 bits
# em palavras de 32 bits considerando DOIS casos:
# 
#    1) Cada linha inicia em uma nova palavra.
#       Caso a linha nao complete multiplos de 4 bytes,
#       o restante da palavra eh preenchido com zeros.
#
#    2) Os bytes das linhas sao empacotados continuamente,
#       sem padding entre linhas.
#       Apenas a ultima palavra pode conter padding.
#-------------------------------------------------------------------------
# Autor: Lucas Farias Martis
# Email: lucas.martins@ee.ufcg.edu.br
# Data: 2026-05-18
# Uso de LLMs: sim
#==========================================================================

import math
import numpy as np
import pandas as pd

def print_matrix(title, mat):

    print("=" * 50)
    print("\t",title)
    print("=" * 50)

    for row in mat:
        print(" ".join(f"{v:3d}" for v in row))

    print()


def chunk_list(lst, chunk_size):

    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]


def format_word(word_bytes):

    return " | ".join(f"{b:02X}" for b in word_bytes)


#============================================================
# CASO 1
# Cada linha alinhada em palavras de 32 bits
#============================================================

def pack_case1(matrix):

    memory = []

    for row in matrix:

        row_bytes = list(row)

        # Padding para multiplo de 4
        while len(row_bytes) % 4 != 0:
            row_bytes.append(0)

        words = chunk_list(row_bytes, 4)

        memory.extend(words)

    return memory


#============================================================
# CASO 2
# Empacotamento continuo
#============================================================

def pack_case2(matrix):

    flat = matrix.flatten().tolist()

    while len(flat) % 4 != 0:
        flat.append(0)

    memory = chunk_list(flat, 4)

    return memory


#============================================================
# Impressao da memoria
#============================================================

def print_memory(title, memory):

    print("-" * 70)
    print(title)
    print("-" * 70)

    for idx, word in enumerate(memory):

        print(
            f"Word[{idx:03d}] : "
            f"{format_word(word)}"
        )

    print()
    print(f"Total de palavras de 32b: {len(memory)}")
    print()


#============================================================
# Analise detalhada
#============================================================

def detailed_example(N, M, start_value=0):

    print("\n")
    print("#" * 80)
    print(f"EXEMPLO DETALHADO - MATRIZ {N}x{M}")
    print("#" * 80)
    print()

    matrix = np.arange(
        start_value,
        start_value + (N * M),
        dtype=np.uint8
    ).reshape(N, M)

    print_matrix("MATRIZ ORIGINAL", matrix)

    # ========================================================
    # CASO 1
    # ========================================================

    mem_case1 = pack_case1(matrix)

    print_memory(
        "CASO 1 - LINHAS ALINHADAS COM PADDING",
        mem_case1
    )

    # ========================================================
    # CASO 2
    # ========================================================

    mem_case2 = pack_case2(matrix)

    print_memory(
        "CASO 2 - EMPACOTAMENTO CONTINUO",
        mem_case2
    )


#============================================================
# Calculo quantitativo
#============================================================

def calc_case1_words(N, M):

    words_per_row = math.ceil(M / 4)

    return N * words_per_row


def calc_case2_words(N, M):

    total_bytes = N * M

    return math.ceil(total_bytes / 4)


#============================================================
# Exemplos detalhados
#============================================================

detailed_example(5, 5)
detailed_example(10, 10, start_value=100)


#============================================================
# Tabelas maiores
#============================================================

large_cases = [
    (16, 16),
    (16, 17),
    (32, 32),
    (32, 33),
    (64, 64),
    (64, 65),
    (128, 128),
    (256, 256),
    (512, 512),
    (1024, 1024),
]

table_case1 = []
table_case2 = []


#============================================================
# CASO 1
#============================================================

for N, M in large_cases:

    words32 = calc_case1_words(N, M)

    table_case1.append({
        "N": N,
        "M": M,
        "Palavras_32b": words32,
        "Palavras_64b": math.ceil((words32 * 4) / 8)
    })


#============================================================
# CASO 2
#============================================================

for N, M in large_cases:

    words32 = calc_case2_words(N, M)

    table_case2.append({
        "N": N,
        "M": M,
        "Palavras_32b": words32,
        "Palavras_64b": math.ceil((words32 * 4) / 8)
    })


#============================================================
# Exibe tabela CASO 1
#============================================================

print("\n")
print("=" * 80)
print("TABELA - CASO 1")
print("LINHAS ALINHADAS COM PADDING")
print("=" * 80)

df1 = pd.DataFrame(table_case1)

print(df1.to_string(index=False))


#============================================================
# Exibe tabela CASO 2
#============================================================

print("\n")
print("=" * 80)
print("TABELA - CASO 2")
print("EMPACOTAMENTO CONTINUO")
print("=" * 80)

df2 = pd.DataFrame(table_case2)

print(df2.to_string(index=False))

print()