module tea
import json

// Response is a placeholder response object
pub struct Response {
pub:
	status string
}

// Validators holds all the route data validators
pub struct Validators<T> {
pub mut:
	validators map[string]fn(mut T)
}

// from_map<T> is a less than ideal parameter decoder
pub fn from_map<T>(params map[string]string) T {
	// hacker man
	data := json.encode(params)
	// only string values will properly be decoded..
	// your T.is_valid function should properly check the fields
	return json.decode(T, data)
}

// decode_model<V> will unpack the request json into the given struct
pub fn decode_model<V>(data string) V {
	model := json.decode(V, data) or { V{} }
	raw_model := V{}

	if model == raw_model {
		println('Data is completely invalid')
	}

	return model
}

