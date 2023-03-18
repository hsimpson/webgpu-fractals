export function createShaderModuleFromString(code: string, device: GPUDevice) {
  return device.createShaderModule({ code });
}

export async function createShaderModuleFromPath(path: string, device: GPUDevice) {
  const res = await fetch(path);
  const code = await res.text();
  return createShaderModuleFromString(code, device);
}
