From node:latest
WORKDIR /apps
ADD . .
Run npm install
CMD ["node" , "index.js"]
