import http from 'k6/http'
import { check, sleep } from 'k6'

const rnd16 = (size) => [...Array(size)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');
const BASE_URL = __ENV.BASE_URL
if (BASE_URL === undefined) 
    throw new Error('Please provide BASE_URL environment variable');
export const options = { systemTags: ['status', 'method', 'check'], };

export default function () {
    const data = { title: 'test-' + rnd16(10), description: 'this is a test', completed: false };
    let res = http.get(`${BASE_URL}/api/todos/`);                                                // list todos
    check(res, { 'success list': (r) => r.status === 200 });
    res = http.post(`${BASE_URL}/api/todos/`, data);                                             // add the new one
    if (check(res, { 'success post': (r) => r.status === 201 })) {                               
        let id = res.json().id;
        res = http.get(`${BASE_URL}/api/todos/${id}/`);                                          // get just added
        if (check(res, { 'success get': (r) => r.status === 200 })) {
            let newdata = res.json();
            newdata.completed = true;
            res = http.put(`${BASE_URL}/api/todos/${id}/`, newdata);                             // edit
            check(res, { 'success put': (r) => r.status === 200 });
            res = http.del(`${BASE_URL}/api/todos/${id}/`);                                      // delete
            check(res, { 'success delete': (r) => r.status === 204 });
        }
        else 
            check(res, { 'success put': false, 'success delete': false });                       // count if get failed
    }
    else 
        check(res, { 'success get': false, 'success put': false, 'success delete': false });     // count if create failed
    
    res = http.get(`${BASE_URL}/api/todos/`);
    check(res, { 'success list': (r) => r.status === 200 });                                     // list todos
    sleep(0.5);
}
