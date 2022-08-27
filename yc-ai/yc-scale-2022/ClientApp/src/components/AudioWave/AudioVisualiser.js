import React, { Component } from 'react';
import PropTypes from 'prop-types';

export default class AudioVisualiser extends Component {
    static propTypes = {
        audioData: PropTypes.object.isRequired,
    };

    constructor(props) {
        super(props);
        this.canvas = React.createRef();
    }

    componentDidUpdate() {
        this.draw();
    }

    draw() {
        const { audioData } = this.props;

        const DEFAULT_HEIGHT = 20;
        const AUDIO_MAX = 256;
        const LINE_WIDTH = 1;
        const GAP_WIDTH = 3;

        const canvas = this.canvas.current;
        const height = canvas.height;
        const width = canvas.width;
        const context = canvas.getContext('2d');

        const cells = width / (LINE_WIDTH + GAP_WIDTH);
        const skips = (audioData.length / cells).toFixed(0);

        context.fillStyle = '#027BF3';
        context.clearRect(0, 0, width, height);

        for (let i = 0, x = GAP_WIDTH; i < cells && x < width; i++) {
            const audioHeight = Math.abs(audioData[i * skips] - AUDIO_MAX / 2);
            const cellHeight =
                ((audioHeight * 2 + DEFAULT_HEIGHT) / (DEFAULT_HEIGHT + AUDIO_MAX)) * height;
            const cellWidth = LINE_WIDTH;
            const y = height * 0.5 - cellHeight / 2;

            context.fillRect(x, y, cellWidth, cellHeight);
            x += GAP_WIDTH + LINE_WIDTH;
        }
    }

    render() {
        return <canvas width="400" height="80" ref={this.canvas} />;
    }
}