import React from 'react';

const NoWebGPU = () => {
  return (
    <div className="text-red-600 text-xl font-bold p-5">
      Your browser does not support WebGPU yet{' '}
      <a
        className="underline"
        target="_blank"
        rel="noreferrer"
        href="https://github.com/gpuweb/gpuweb/wiki/Implementation-Status">
        (Implementation Status)
      </a>
      <br />
      If you want to try this out:
      <ul className="list-disc list-inside">
        <li>In Chrome enable a flag: chrome://flags/#enable-unsafe-webgpu</li>
      </ul>
      <br />
      Additional information:
      <ul className="list-disc list-inside">
        <li>
          <a target="_blank" rel="noreferrer" href="https://github.com/gpuweb/gpuweb">
            Github repo
          </a>
        </li>
        <li>
          <a target="_blank" rel="noreferrer" href="https://en.wikipedia.org/wiki/WebGPU">
            Wikipedia article
          </a>
        </li>
      </ul>
    </div>
  );
};

export default NoWebGPU;
