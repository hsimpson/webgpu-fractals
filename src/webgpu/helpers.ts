export function supportsWebGPU(): boolean {
  if (navigator.gpu) {
    return true;
  }
  return false;
}
