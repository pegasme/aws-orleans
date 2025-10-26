import { Box, Button, Card, FormControl, FormLabel, Stack, TextField, Typography } from "@mui/material";
import React from "react";
import { useState } from "react";

const CreateUser = () => {
  const [nameError, setNameError] = useState(false);
  const [keyError, setKeyError] = useState(false);

  const [nameErrorMessage, setNameErrorMessage] = useState('');
  const [keyErrorMessage, setKeyErrorMessage] = useState('');

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    // Handle user creation logic here
    alert(`User created: ${name}`);
  };

  const validateInputs = () => {
    const name = document.getElementById("name") as HTMLInputElement;
    const key = document.getElementById("key") as HTMLInputElement;

    let isValid = true;
    if (!name.value || name.value.length < 1) {
      setNameError(true);
      setNameErrorMessage('Name is required.');
      isValid = false;
    } else {
      setNameError(false);
      setNameErrorMessage('');
    }

    if (!key.value || key.value.length < 1) {
      setKeyError(true);
      setKeyErrorMessage('Key is required.');
      isValid = false;
    } else {
      setKeyError(false);
      setKeyErrorMessage('');
    }
    return isValid;
  };

  return (
    <Stack spacing={2}>
      <Card variant="outlined">
        <Typography
            component="h1"
            variant="h4"
            sx={{ width: '100%', fontSize: 'clamp(2rem, 10vw, 2.15rem)' }}
          >
            Sign up
          </Typography>
             <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}> 

              <FormControl>
              <FormLabel htmlFor="name">Name</FormLabel>
              <TextField
                autoComplete="name"
                name="name"
                required
                fullWidth
                id="name"
                error={nameError}
                helperText={nameErrorMessage}
                color={nameError ? 'error' : 'primary'}
              />
            </FormControl>
            <FormControl>
              <FormLabel htmlFor="key">Key</FormLabel>
              <TextField
                required
                fullWidth
                id="key"
                name="key"
                autoComplete="key"
                variant="outlined"
                error={keyError}
                helperText={keyErrorMessage}
                color={keyError ? 'error' : 'primary'}
              />
            </FormControl>
                <Button type="submit" fullWidth variant="contained" onClick={validateInputs}>
                  Sign up
                </Button>
              </Box>
            </Card>
    </Stack>
  );
};

export default CreateUser;