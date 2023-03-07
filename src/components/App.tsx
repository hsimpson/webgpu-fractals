import React from 'react';
import { supportsWebGPU } from '../webgpu';
import NoWebGPU from './NoWebGPU';
import Renderer from './Renderer';

const App = () => {
  const isWebGPUSupported = supportsWebGPU();
  return isWebGPUSupported ? <Renderer /> : <NoWebGPU />;
};

export default App;
