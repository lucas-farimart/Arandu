import numpy as np

np.random.seed(1)

N_IN  = 784
N_OUT = 64

# ----------------------------
# Dados
# ----------------------------
x = np.random.randint(-128, 127, N_IN, dtype=np.int8)
W = np.random.randint(-128, 127, (N_OUT, N_IN), dtype=np.int8)

# ----------------------------
# Golden
# ----------------------------
golden = np.zeros(N_OUT, dtype=np.int32)

for j in range(N_OUT):
    golden[j] = np.sum(
        x.astype(np.int32) * W[j].astype(np.int32)
    )

# ----------------------------
# Export helpers
# ----------------------------
def save_mem_1d(filename, data):
    with open(filename, "w") as f:
        for v in data:
            f.write(f"{(int(v) & 0xFF):02x}\n")

def save_mem_2d(filename, data):
    with open(filename, "w") as f:
        for row in data:
            for v in row:
                f.write(f"{(int(v) & 0xFF):02x}\n")

def save_golden(filename, data):
    with open(filename, "w") as f:
        for v in data:
            f.write(f"{(int(v) & 0xFFFFFFFF):08x}\n")

# ----------------------------
# Save
# ----------------------------
save_mem_1d("input.mem", x)
save_mem_2d("weights.mem", W)
save_golden("golden.mem", golden)

print("Arquivos gerados!")