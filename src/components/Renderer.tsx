import React, { useEffect, useRef } from 'react';
import { WebGPURenderer } from '../webgpu';

const Renderer = () => {
  const canvasEl = useRef<HTMLCanvasElement>(null);
  const webGPURender = useRef<WebGPURenderer | null>(null);

  useEffect(() => {
    if (canvasEl.current && !webGPURender.current) {
      webGPURender.current = new WebGPURenderer(canvasEl.current);
      void webGPURender.current.start();
    }
  }, []);

  return <canvas className="h-full w-full" ref={canvasEl} />;
};

export default Renderer;
