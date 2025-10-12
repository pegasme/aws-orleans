import React, { useEffect } from 'react';
import './styles/index.scss';
import Container from '@mui/material/Container';
import CreateUser from './pages/CreateUser';
import Typography from '@mui/material/Typography';

export const App = () => {

  return <Container maxWidth={false}>
    <Typography variant="h4" component="h1" sx={{ mb: 2 }}>Adventure Game</Typography>
    <CreateUser />
    </Container>;
};

export default App;