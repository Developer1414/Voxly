module.exports = {
  apps: [
    {
      name: "server",
      script: "server.mjs",
      instances: 1,
      exec_mode: "fork",

      interpreter: "node",

      cwd: "/root/voxly-backend",

      env_file: ".env",

      env: {
        NODE_ENV: "production",
      },

      watch: false,
      max_memory_restart: "1G",
    },
  ],
};
