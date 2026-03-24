import { useEffect, useRef } from 'react';
import { WebGPURenderer } from '../webgpu';

const Renderer = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const webGPURendererRef = useRef<WebGPURenderer | null>(null);

  useEffect(() => {
    if (canvasRef.current && !webGPURendererRef.current) {
      webGPURendererRef.current = new WebGPURenderer(canvasRef.current);
      void webGPURendererRef.current.start();
    }
  }, []);

  return <canvas className="h-full w-full" ref={canvasRef} />;
};

export default Renderer;
