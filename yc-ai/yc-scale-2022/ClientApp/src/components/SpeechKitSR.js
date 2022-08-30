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
        if (!data.Chunks) {
            return;
        }

        const tempText = data.Chunks[0].Alternatives[0].Text;
        const isFinal = data.Chunks[0].final;

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
            this.setState({ isRecording: true, showRecording: true });

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

    stopRecording = () => {
        this.recorder.stop(() => {
            this.ws.close();
            clearInterval(this.timer);
            this.setState({ isRecording: false, wsConnected: false, stream: null });
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

        return <div className={b('text')}>{`${text} ${tempText}`}</div>;
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
                    </div>
                    <div className={b('bottom')}>                       
                        <Button onClick={isRecording ? this.stopRecording : this.initialize}>
                            {isRecording ? "Завершить" : "Повторить"}
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

