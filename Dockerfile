# Example Dockerfile

FROM node:latest

WORKDIR /apps

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]

