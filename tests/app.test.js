const request = require('supertest');
const app = require('../src/app');

describe('GET /', () => {
    it('should return 200 OK and a welcome message', async () => {
        const res = await request(app).get('/');
        expect(res.statusCode).toEqual(200);
        expect(res.body).toHaveProperty('message');
    });
});

// describe('GET /health', () => {
//     it('should return UP status', async () => {
//         const res = await request(app).get('/health');
//         expect(res.statusCode).toEqual(200);
//         expect(res.body.status).toEqual('UP');
//     });
// });
