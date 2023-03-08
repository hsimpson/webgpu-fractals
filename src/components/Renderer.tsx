import React, { useEffect, useRef } from 'react';
import { WebGPURenderer } from '../webgpu';

const Renderer = () => {
  const canvasEl = useRef<HTMLCanvasElement>(undefined);
  const webGPURender = useRef<WebGPURenderer>(undefined);

  useEffect(() => {
    if (canvasEl.current && !webGPURender.current) {
      webGPURender.current = new WebGPURenderer(canvasEl.current);
      void webGPURender.current.start();
    }
  }, []);

  return <canvas className="w-full h-full" ref={canvasEl} />;
};

export default Renderer;
