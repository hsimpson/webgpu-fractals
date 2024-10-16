import { supportsWebGPU } from '@donnerknalli/webgpu-utils';
import React from 'react';
import NoWebGPU from './NoWebGPU';
import Renderer from './Renderer';

const App = () => {
  const isWebGPUSupported = supportsWebGPU();
  return isWebGPUSupported ? <Renderer /> : <NoWebGPU />;
};

export default App;
