import React, { Component } from 'react';
import PropTypes from 'prop-types';
import AudioVisualiser from './AudioVisualiser';

export default class AudioWave extends Component {
    static propTypes = {
        audio: PropTypes.object.isRequired,
        className: PropTypes.string,
    };

    static defaultProps = {
        className: '',
    };

    state = {
        audioData: new Uint8Array(0),
    };

    componentDidMount() {
        const { audio } = this.props;

        this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
        this.analyser = this.audioContext.createAnalyser();
        this.dataArray = new Uint8Array(this.analyser.frequencyBinCount);
        this.source = this.audioContext.createMediaStreamSource(audio);
        this.source.connect(this.analyser);
        this.rafId = requestAnimationFrame(this.tick);
    }

    componentWillUnmount() {
        cancelAnimationFrame(this.rafId);
        this.analyser.disconnect();
        this.source.disconnect();
    }

    tick = () => {
        this.analyser.getByteTimeDomainData(this.dataArray);
        this.setState({ audioData: this.dataArray });
        this.rafId = requestAnimationFrame(this.tick);
    };

    render() {
        const { className } = this.props;
        const { audioData } = this.state;

        return (
            <div className={className}>
                <AudioVisualiser audioData={audioData} />
            </div>
        );
    }
}