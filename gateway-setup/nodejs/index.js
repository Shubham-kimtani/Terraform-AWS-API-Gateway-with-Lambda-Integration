console.log("Loading Fucntion")

exports.handler = async (event, context) => {
let jsonResponse = {"hello":"world"}
    const response = {
        statusCode: 200,
        body: JSON.stringify(jsonResponse),
    };
    return response;
};
