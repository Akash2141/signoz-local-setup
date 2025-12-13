import dotenv from 'dotenv';
import { createHistogram, initializeOtlp } from './metrics';

dotenv.config();

console.log("process.env::", process.env);

initializeOtlp();
const testHistogram = createHistogram('test-histogram');

function simulateCheckout() {
    //console.log(`Simulating checkout with duration ...`);

    testHistogram.record(4000, {
        'checkout.status': 'success',
        'user.tier': 'premium'
    });

}

setInterval(() => {
    // const randomDuration = Math.floor(Math.random() * 3000);
    simulateCheckout();
}, 100)

console.log('Node.js custom metrics application running...');