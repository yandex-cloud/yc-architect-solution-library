import React, { Component } from 'react';
import { Link } from '@yandex-cloud/uikit';
import { Table } from '@yandex-cloud/uikit';
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

              <table className='uk-table .uk-table-striped' aria-labelledby="tabelLabel">
        <thead>
          <tr>
            <th className='text'>Время</th>
            <th>😐 Без эмоций</th>
            <th>😂 Радость</th>
            <th>😮 Удивление</th>
            <th>😞 Грусть</th>
            <th>😨 Страх</th>
            <th>😡 Злость</th>
            <th>Текст</th>
          </tr>
        </thead>
        <tbody>
            {sentiments.map(sentiments =>
        <tr key={sentiments.recognitionId}>
            <td>{(new Intl.DateTimeFormat('ru-RU', { hour: '2-digit', minute: '2-digit' }).format(convertUTCDateToLocalDate(new Date(sentiments.startDate))))}</td>
            <td>{sentiments.noEmotion.toFixed(2)}</td>
            <td>{sentiments.joy.toFixed(2)}</td>
            <td>{sentiments.surprise.toFixed(2)}</td>
            <td>{sentiments.sadness.toFixed(2)}</td>
            <td>{sentiments.fear.toFixed(2)}</td>
            <td>{sentiments.anger.toFixed(2)}</td>
                    <td>{(() => {
                        if (sentiments.trackerKey) {
                            return (
                                <Link href={"https://tracker.yandex.ru/" + sentiments.trackerKey}>{sentiments.text}</Link>
                            )
                        } else {
                            return (
                                <div className="asr-txt">{sentiments.text}</div>
                            )
                        }
                    })()}</td>
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
