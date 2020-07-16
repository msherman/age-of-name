import React from "react";
import {Header} from "../Header/Header";
import './LandingPage.css';
import {Typography} from "@material-ui/core";

interface LandingPageState {
    name: string;
    age: string;
}

export class LandingPage extends React.Component<any, LandingPageState> {
    public constructor(props: any) {
        super(props);
        this.state = {
            name: "",
            age: "0"
        };
    }

    public componentDidMount(): void {
        fetch('https://api.agify.io/?name=batman')
            .then((response: any) => {
                const reader = response.body.getReader();

                reader.read().then((data: any) => {
                    const jsonResponse: any = JSON.parse(new TextDecoder("utf-8").decode(data.value));
                    console.log(jsonResponse);
                    this.setState({name: jsonResponse.name, age: jsonResponse.age});
                });
            });
    }

    public render() {
        return (
          <div className="landing-page-container">
              <Header name={this.state.name}/>
              <Typography variant="h2">
                {"Age: " + this.state.age}
              </Typography>
          </div>
        );
    }
}