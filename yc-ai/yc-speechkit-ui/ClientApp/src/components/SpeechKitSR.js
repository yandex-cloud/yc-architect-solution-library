import React from 'react';
import PropTypes from 'prop-types';
import block from 'bem-cn-lite';
import _ from 'lodash';
import { YCSelect } from '@yandex-data-ui/common';
import Recorder from '@yandex-data-ui/audio-recorder';

import AudioWave from './AudioWave/AudioWave';
import { secondsToMMSS } from './utils';

import './SpeechKitSR.scss';

const b = block('SpeechKitSR');

const MAX_SECONDS = 60;

const getLangItems = _.memoize((i18nK) => [
    { title: i18nK('lang-russian'), value: 'ru-RU' },
    { title: i18nK('lang-english'), value: 'en-US' },
    { title: i18nK('lang-turkey'), value: 'tr-TR' },
]);

export class SpeechKitSR extends React.Component {
    static propTypes = {
        locale: PropTypes.object.isRequired,
        i18nK: PropTypes.func,
        isConstructorVersion: PropTypes.bool,
    };

    constructor(props) {
        super(props);
        const langItems = getLangItems(props.i18nK);

        this.state = {
            isMounted: false,
            isRecording: false,
            showRecording: false,
            wsConnected: false,
            stream: null,
            seconds: 0,
            langItems,
            language: props.locale.lang === 'ru' ? langItems[0].value : langItems[1].value,
            text: '',
            tempText: '',
            error: null,
        };
    }

    componentDidMount() {
        this.setState({ isMounted: true });
    }

    initializeWS = (config) => {
        this.ws = new WebSocket(`wss://${window.location.host}/api/speechkit/recognition`);

        this.ws.onmessage = ({ data: messageData }) => {
            const { type, data } = JSON.parse(messageData);

            switch (type) {
                case 'connect':
                    this.setState({ wsConnected: true });
                    break;
                case 'data':
                    this.processText(data);
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
        if (!data.chunks) {
            return;
        }

        const tempText = data.chunks[0].alternatives[0].text;
        const isFinal = data.chunks[0].final;

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

    renderStartScreen() {
        const { i18nK } = this.props;
        const { language, langItems } = this.state;

        return (
            <div className={b('start')}>
                <div className={b('wrap')}>
                    <h4 className={b('title')}>{i18nK('sr-title')}</h4>
                    <FormLayout.Row className={b('select')} title={i18nK('sr-form-language')}>
                        <YCSelect
                            size="n"
                            name="lang"
                            value={language}
                            onUpdate={this.changeLanguage}
                            items={langItems}
                            showSearch={false}
                        />
                    </FormLayout.Row>
                    <Button type="submit" size="l" view="action" onClick={this.initialize}>
                        {i18nK('sr-button_start')}
                    </Button>
                </div>
            </div>
        );
    }

    renderText() {
        const { i18nK } = this.props;
        const { text, tempText, error } = this.state;

        if (error) {
            return null;
        }

        if (text === '' && tempText === '') {
            return (
                <div className={`${b('placeholder')} ${b('text')}`}>{i18nK('sr-lets_speak')}</div>
            );
        }

        return <div className={b('text')}>{`${text} ${tempText}`}</div>;
    }

    renderRecordings() {
        const { i18nK } = this.props;
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
                                <div className={b('error')}>{i18nK('sr-error')}</div>
                            ) : (
                                ''
                            )}
                        </div>
                        {this.renderText()}
                    </div>
                    <div className={b('bottom')}>
                        {isRecording ? (
                            ''
                        ) : (
                            <Button
                                type="button"
                                size="l"
                                view="outlined"
                                className={b('button')}
                                onClick={this.backToLanguage}
                            >
                                {i18nK('sr-button_back')}
                            </Button>
                        )}
                        <Button
                            type="submit"
                            size="l"
                            view="action"
                            className={b('button')}
                            onClick={isRecording ? this.stopRecording : this.initialize}
                        >
                            {isRecording ? i18nK('sr-button_end') : i18nK('sr-button_again')}
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
            <Section id="speechkit-demo" className={b({ constructor: isConstructorVersion })}>
                {showRecording ? this.renderRecordings() : this.renderStartScreen()}
            </Section>
        );
    }
}

export default compose(withLocale, withTranslation('speechkit-demo'))(SpeechKitSR);