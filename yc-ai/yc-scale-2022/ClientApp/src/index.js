import 'bootstrap/dist/css/bootstrap.css';
import '@yandex-cloud/uikit/styles/styles.scss'
import "@yandex-cloud/uikit/styles/brand.scss";
import "@yandex-cloud/uikit/styles/mixins.scss";
import React from 'react';
import ReactDOM from 'react-dom';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import registerServiceWorker from './registerServiceWorker';

const baseUrl = document.getElementsByTagName('base')[0].getAttribute('href');
const rootElement = document.getElementById('root');


ReactDOM.render(
  <BrowserRouter basename={baseUrl}>
    <App />
  </BrowserRouter>,
  rootElement);

registerServiceWorker();

