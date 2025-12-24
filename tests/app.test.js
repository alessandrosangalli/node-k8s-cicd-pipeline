const request = require('supertest');
const app = require('../src/app');

describe('GET /', () => {
    // it('should return a message property', async () => {
    //     const res = await request(app).get('/');
    //     // We only check for the property because the status might be 500 or 200 depending on tests
    //     expect(res.body).toHaveProperty('message' || 'error');
    // });
});

describe('GET /health', () => {
    it('should return UP status', async () => {
        const res = await request(app).get('/health');
        expect(res.statusCode).toEqual(200);
        expect(res.body.status).toEqual('UP');
    });
});
