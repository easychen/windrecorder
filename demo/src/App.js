import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';
import axios from 'axios';

class App extends Component {

  state = {"text":"Loading"};

  async componentDidMount()
  {
    this.axios = axios.create();
    this.axios.defaults.timeout = 500;
    window.setTimeout( ()=>this.start(), 1000 );
    window.setTimeout( ()=>this.stop(), 9000 );
  }

  async start()
  {
    this.setState({"text":"Recording..."});
    await this.axios.get( "http://localhost/start" );

  }

  async stop()
  {
    this.setState({"text":"Stopped"});
    await this.axios.get( "http://localhost/stop" );
  }
  
  render()
  {
    return (
      <div className="App">
        <header className="App-header">
          <img src={logo} className="App-logo" alt="logo" />
          <p>
            {this.state.text}
          </p>
          <a
            className="App-link"
            href="https://reactjs.org"
            target="_blank"
            rel="noopener noreferrer"
          >
            Learn React
          </a>
        </header>
      </div>
    );
  }

}

export default App;
