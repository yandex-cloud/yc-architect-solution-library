import React from 'react';
import block from 'bem-cn-lite';
import _ from 'lodash';

import Recorder from './audio-recorder/index';
import AudioWave from './AudioWave/AudioWave';
import { Button } from '@yandex-cloud/uikit';
import { secondsToMMSS } from './utils';
import { configure } from '@yandex-cloud/uikit';
import './SpeechKitSR.scss';


configure({
    lang: 'ru',
});

const b = block('SpeechKitSR');
const MAX_SECONDS = 60;


export class SpeechKitSR extends React.Component {
    
    constructor(props) {
        super(props);
       

        this.state = {
            isMounted: false,
            isRecording: false,
            showRecording: false,
            wsConnected: false,
            stream: null,
            seconds: 0,
            language: 'ru-RU',
            text: '',
            tempText: '',
            emotions: null,
            sessionId: '',
            error: null,
        };
    }

    componentDidMount() {
        this.setState({ isMounted: true });
    }

    initializeWS = (config) => {
        this.ws = new WebSocket(`wss://${window.location.host}/ws`);

        this.ws.onmessage = ({ data: messageData }) => {
            const { type, data } = JSON.parse(messageData);

            switch (type) {
                case 'connect':
                    this.setState({ wsConnected: true });
                    break;
                case 'data':
                    this.processText(JSON.parse(data));
                    break;
                case 'ml':
                   // this.processML(JSON.parse(data));
                    this.setState({ emotions: JSON.parse(data) })
                    break;
                case 'error':
                    this.setState({ error: data });
                    this.stopRecording();
                    break;
            }
        };

        this.ws.onopen = () => {
            this.ws.send(JSON.stringify(config));
        };

        this.ws.onerror = () => {
            this.setState({ error: 'Disconnected' });
        };

        this.ws.onclose = () => {
            this.stopRecording();
        };
    };

    processText = (data) => {
        if (!data.Alternatives) {
            return;
        }
        this.setState({ sessionId: data.SessionId })
        const tempText = data.Alternatives[0].Text;
        const isFinal = data.Final;

        if (isFinal) {
            this.setState(({ text }) => ({
                tempText: '',
                text: `${text} ${tempText}`.trim(),
            }));
        } else {
            this.setState({ tempText });
        }
    };

    initializeAudio = async (cb) => {
        Recorder.initRecorder((stream) => {
            const format = Recorder.FORMAT.PCM48;

            this.setState({ stream });
            this.recorder = Recorder.Recorder(); // eslint-disable-line new-cap
            this.recorder.start((data) => this.sendAudio(data), format);

            cb(format);

            // eslint-disable-next-line no-console
        }, console.error);
    };

    sendAudio = (audio) => {
        if (this.ws && this.state.wsConnected) {
            this.ws.send(audio);
        }
    };

    initialize = async () => {
        const { language } = this.state;
        this.setState({ text: '', tempText: '', seconds: 0, error: null });

        await this.initializeAudio(({ format, sampleRate }) => {
            this.setState({ isRecording: true, showRecording: true, emotions: null });

            this.timer = setInterval(this.timerTick, 1000);

            this.initializeWS({ language, format, sampleRate });
        });
    };

    timerTick = () => {
        const { seconds } = this.state;

        if (seconds >= MAX_SECONDS) {
            this.stopRecording();
        } else {
            this.setState({ seconds: seconds + 1 });
        }
    };

    async populateSentimentsData() {
        const response = await fetch('sentimentsgrid/' + this.state.sessionId);
        const data = await response.json();
        this.setState(this.setState({ emotions: data }));
    }

    stopRecording = () => {
        this.recorder.stop(() => {           
            this.ws.close();
            clearInterval(this.timer);
            this.setState({ isRecording: false, wsConnected: false, stream: null });

           setTimeout(function () { //Start the timer
                    this.populateSentimentsData(); //After 1 second, set render to true
           }.bind(this), 1000)
            
            

        });
    };

    backToLanguage = () => {
        this.setState({ showRecording: false });
    };

    changeLanguage = (language) => {
        this.setState({ language });
    };


    renderText() {
        //const { i18nK } = this.props;
        const { text, tempText, error } = this.state;

        if (error) {
            return null;
        }

        if (text === '' && tempText === '') {
            return (
                <div className={`${b('placeholder')} ${b('text')}`}>Говорите</div>
            );
        }

        return (
            <div className={b('text-placeholder')}>
                <div className={b('text')}>{text} </div>
                <div className={b('text')}>{tempText}</div>
            </div>
        )
    }

    renderSentimentAnalyzis() {
        const { emotions, error } = this.state;

        if (error) {
            return null;
        }
        if (emotions) {
            return (
                <table className="table table-borderless">
                    <thead>
                        <tr>
                            <th>Emotions</th>
                            <th>joy</th>
                            <th>surprise</th>
                            <th>sadness</th>                    
                            <th>fear</th>
                            <th>anger</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td></td>
                            <td>{emotions.joy.toFixed(2)}</td>
                            <td>{emotions.surprise.toFixed(2)}</td>
                            <td>{emotions.sadness.toFixed(2)}</td>
                            <td>{emotions.fear.toFixed(2)}</td>
                            <td>{emotions.anger.toFixed(2)}</td>
                        </tr>
                    </tbody>
                </table>
                )
        } else {
            return null;
        }
    }

    

    renderRecordings() {
        // const { i18nK } = this.props;
        const { isRecording, stream, seconds, error } = this.state;

        return (
            <div className={b('recording')}>
                <div className={b('wrap')}>
                    <div className={b('top')}>
                        <div className={b('time')}>
                            {secondsToMMSS(seconds)} / {secondsToMMSS(MAX_SECONDS)}
                        </div>
                        <div className={b('audio-analyser')}>
                            {stream ? <AudioWave audio={stream} /> : ''}
                            {!stream && error ? (
                                <div className={b('error')}>Произошла ошибка</div>
                            ) : (
                                ''
                            )}
                        </div>
                        {this.renderText()}
                        {this.renderSentimentAnalyzis() }
                    </div>
                    <div className={b('bottom')}>                       
                        <Button size="xl" view="action" onClick={isRecording ? this.stopRecording : this.initialize}>
                            {isRecording ? "Завершить" : "Распознать"}
                        </Button>
                    </div>
                </div>
            </div>
        );
    }

    render() {
        const { isConstructorVersion } = this.props;
        const { isMounted, showRecording } = this.state;

        if (!isMounted) {
            return null;
        }

        return (
            <div id="speechkit-demo" >
                {this.renderRecordings()}
            </div>
        );
    }
}

