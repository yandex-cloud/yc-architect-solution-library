import React, { Component } from 'react';
import { convertUTCDateToLocalDate } from './utils'

export class FetchData extends Component {
  static displayName = FetchData.name;

  constructor(props) {
    super(props);
    this.state = { sentiments: [], loading: true };
  }

  componentDidMount() {
    this.populateSentimentsData();
    }


  
  static renderSentimentsTable(sentiments) {
      return (
          <div>
      <table className='table table-striped' aria-labelledby="tabelLabel">
        <thead>
          <tr>
            <th >Time</th>
            <th>NoEmotion</th>
            <th>Joy</th>
            <th>Surprise</th>
            <th>Sadness</th>            
            <th>Fear</th>
            <th>Anger</th>
            <th>Text</th>
          </tr>
        </thead>
        <tbody>
            {sentiments.map(sentiments =>
        <tr key={sentiments.recognitionId}>
            <td>{(convertUTCDateToLocalDate(new Date(sentiments.startDate))).toLocaleTimeString()}</td>
            <td>{sentiments.noEmotion.toFixed(2)}</td>
            <td>{sentiments.joy.toFixed(2)}</td>
            <td>{sentiments.surprise.toFixed(2)}</td>
            <td>{sentiments.sadness.toFixed(2)}</td>
            <td>{sentiments.fear.toFixed(2)}</td>
            <td>{sentiments.anger.toFixed(2)}</td>
            <td>{sentiments.text}</td>
        </tr>
          )}
        </tbody>
              </table>
          </div>
    );
  }

  render() {
    let contents = this.state.loading
      ? <p><em>Loading...</em></p>
      : FetchData.renderSentimentsTable(this.state.sentiments);

    return (
      <div>
        <h1 id="tabelLabel" >Sentiment analysid result</h1>
        <p>Analysis requests history.</p>
        {contents}
      </div>
    );
  }

  async populateSentimentsData() {
    const response = await fetch('sentimentsgrid');
    const data = await response.json();
    this.setState({ sentiments: data, loading: false });
  }
}
