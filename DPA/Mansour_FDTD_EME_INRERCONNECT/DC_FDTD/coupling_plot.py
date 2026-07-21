import re
import numpy as np
import matplotlib.pyplot as plt

path = "D:\\KIT\\KSOP\\4th semester_summer26\\PICDA\\labs\\DPA\\Directional coupler\\FDTD\\S-parameter of 4 DC\\DC_FDTD_sparams_1stStage_1stCoupler.dat"
lines = open(path, "r").read().splitlines()

blocks = {}
i = 0
while i < len(lines):
    line = lines[i].strip()
    m = re.match(r'\("Port (\d+)","mode 1",1,"Port (\d+)",1,"transmission"\)', line)
    if m:
        src = int(m.group(1))
        dst = int(m.group(2))
        data = []
        i += 2  # skip the block-size line
        while i < len(lines) and not lines[i].strip().startswith('("Port'):
            parts = lines[i].split()
            if len(parts) == 3:
                data.append([float(parts[0]), float(parts[1]), float(parts[2])])
            i += 1
        blocks[(src, dst)] = np.array(data)
    else:
        i += 1

c0 = 299792458.0

def get_sorted_power(src, dst):
    arr = blocks[(src, dst)]
    freq = arr[:, 0]
    S_mag = arr[:, 1]
    wavelength_nm = c0 / freq * 1e9
    power = S_mag**2
    order = np.argsort(wavelength_nm)
    return wavelength_nm[order], power[order]

# Plot S-parameter power in linear scale
plt.figure(figsize=(7.5, 4.8))
for dst in [1, 2, 3, 4]:
    wl, power = get_sorted_power(1, dst)
    plt.plot(wl, power, linewidth=2, label=f"$|S_{{{dst}1}}|^2$")
plt.axvline(1301, linestyle="--", linewidth=1.2, label="$\\lambda_0=1301$ nm")
plt.xlabel("Wavelength (nm)")
plt.ylabel("Power transmission")
plt.title("Directional coupler S-parameter sweep, input Port 1")
plt.grid(True, alpha=0.35)
plt.legend()
plt.tight_layout()
linear_path = "D:\\KIT\\KSOP\\4th semester_summer26\\PICDA\\labs\\DPA\\Directional coupler\\FDTD\\S-parameter of 4 DC\\DC_sparams_linear.png"
plt.savefig(linear_path, dpi=300, bbox_inches="tight")
plt.show()

# Plot S-parameter power in dB scale
plt.figure(figsize=(7.5, 4.8))
for dst in [1, 2, 3, 4]:
    wl, power = get_sorted_power(1, dst)
    plt.plot(wl, 10*np.log10(np.maximum(power, 1e-12)), linewidth=2, label=f"$|S_{{{dst}1}}|^2$")
plt.axvline(1301, linestyle="--", linewidth=1.2, label="$\\lambda_0=1301$ nm")
plt.xlabel("Wavelength (nm)")
plt.ylabel("Power transmission (dB)")
plt.title("Directional coupler S-parameter sweep in dB, input Port 1")
plt.grid(True, alpha=0.35)
plt.legend()
plt.tight_layout()
db_path = "D:\\KIT\\KSOP\\4th semester_summer26\\PICDA\\labs\\DPA\\Directional coupler\\FDTD\\S-parameter of 4 DC\\DC_sparams_dB.png"
plt.savefig(db_path, dpi=300, bbox_inches="tight")
plt.show()

print(f"Saved plots:\n{linear_path}\n{db_path}")