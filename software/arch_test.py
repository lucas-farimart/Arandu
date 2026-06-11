import numpy as np

print("\n============================================")
print("      TESTE DE PERMUTACAO POR LINHA 8x8       ")
print("============================================\n")

# Vetor de entrada

x = np.array([1,2,3,4,5,6,7,8])

print("x =", x)

# Matriz original

W = np.array([
    [1,2,3,4,5,6,7,8],
    [1,2,3,4,5,6,7,8],
    [1,2,3,4,5,6,7,8],
    [1,2,3,4,5,6,7,8],
    [1,2,3,4,5,6,7,8],
    [1,2,3,4,5,6,7,8],
    [1,2,3,4,5,6,7,8],
    [1,2,3,4,5,6,7,8]
])

print("W =\n", W)

# Resultado matematico desejado
y_ref = W @ x

# ---------------------------------------------
# Cria matriz compensada
# Linhas impares recebem colunas invertidas
# ---------------------------------------------

W_comp = W.copy()

for row in range(W.shape[0]):
    if row % 2 == 1:
        W_comp[row] = W_comp[row][::-1]

# ---------------------------------------------
# Simula o hardware
# ---------------------------------------------
y_hw = np.zeros(8, dtype=int)

print()
for row in range(8):
    if row % 2 == 0:
        x_hw = x
    else:
        x_hw = x[::-1]
    print("ROW", row)    
    print("x_hw =", x_hw)
    print("W_hw =", W_comp[row])
    print()
    y_hw[row] = np.dot(W_comp[row], x_hw)

# ---------------------------------------------
# Resultados
# ---------------------------------------------

print("\nResultado referencia:")
print(y_ref)

print("\nResultado hardware:")
print(y_hw)

print("\nIguais:", np.array_equal(y_ref, y_hw))

print("\n============================================")
print("     TESTE GENERICO MxN COM RANDOMICOS        ")
print("============================================\n")

# Dimensoes arbitrarias
M = 5
N = 7
np.random.seed(0)

# Dados aleatorios

x = np.random.randint(-20, 21, size=N)
W = np.random.randint(-20, 21, size=(M, N))
print("x =", x)
print("W =\n", W)

# Resultado referencia

y_ref = W @ x

# ---------------------------------------------
# Compensacao das linhas
# ---------------------------------------------

W_comp = W.copy()

for row in range(M):

    if row % 2 == 1:
        W_comp[row] = W_comp[row][::-1]

# ---------------------------------------------
# Simulacao do hardware
# ---------------------------------------------

y_hw = np.zeros(M, dtype=int)

print()
for row in range(M):
    if row % 2 == 0:
        x_hw = x
    else:
        x_hw = x[::-1]
    print("ROW", row)    
    print("x_hw =", x_hw)
    print("W_hw =", W_comp[row])
    print()
    y_hw[row] = np.dot(W_comp[row], x_hw)

# ---------------------------------------------
# Verificacao
# ---------------------------------------------

print("M =", M)
print("N =", N)

print("\nResultado referencia:")
print(y_ref)

print("\nResultado hardware:")
print(y_hw)

print("\nIgual:",
      np.array_equal(y_ref, y_hw))

if not np.array_equal(y_ref, y_hw):

    print("\nReferencia:")
    print(y_ref)

    print("\nHardware:")
    print(y_hw)

else:
    print("\nPASSOU NO TESTE\n")