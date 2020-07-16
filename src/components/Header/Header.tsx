import React from "react";
import {Typography} from "@material-ui/core";
import './Header.css';

interface HeaderProps {
    name: string;
}

export class Header extends React.Component<HeaderProps, any> {
    public render() {
        return (
            <div className="header-container">
                <Typography className="header" variant="h2">I'm {this.props.name}</Typography>
            </div>
        )
    }
}