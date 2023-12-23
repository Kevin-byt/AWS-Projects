exports.handler = async (event) => {
    console.log(JSON.stringify(event));
    for (const record of event.Records) {
    const data = JSON.parse(Buffer.from(record.kinesis.data, 'base64'));
    console.log('consumer #1', data);
    }
    };