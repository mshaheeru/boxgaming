'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Container,
  Paper,
  Title,
  TextInput,
  PasswordInput,
  Button,
  Stack,
  Alert,
} from '@mantine/core';
import { IconAlertCircle } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import api from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [password, setPassword] = useState('');
  const [step, setStep] = useState<'phone' | 'otp' | 'password'>('phone');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSendOTP = async () => {
    if (!phone) {
      setError('Please enter your phone number');
      return;
    }

    setLoading(true);
    setError('');

    try {
      await api.post('/auth/send-otp', { phone });
      setStep('otp');
      notifications.show({
        title: 'OTP Sent',
        message: 'Please check your phone for the OTP code',
        color: 'blue',
      });
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to send OTP');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOTP = async () => {
    if (!otp) {
      setError('Please enter the OTP');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await api.post('/auth/verify-otp', { phone, otp });
      const { accessToken, user } = response.data;

      if (user.role !== 'admin') {
        setError('Access denied. Admin access required.');
        return;
      }

      localStorage.setItem('admin_token', accessToken);
      router.push('/dashboard');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Invalid OTP');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container size={420} my={40}>
      <Title ta="center" mb="xl">
        Admin Portal
      </Title>

      <Paper withBorder shadow="md" p={30} mt={30} radius="md">
        <Stack gap="md">
          {error && (
            <Alert icon={<IconAlertCircle size={16} />} color="red">
              {error}
            </Alert>
          )}

          {step === 'phone' && (
            <>
              <TextInput
                label="Phone Number"
                placeholder="+923001234567"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                required
              />
              <Button fullWidth onClick={handleSendOTP} loading={loading}>
                Send OTP
              </Button>
            </>
          )}

          {step === 'otp' && (
            <>
              <TextInput
                label="OTP Code"
                placeholder="123456"
                value={otp}
                onChange={(e) => setOtp(e.target.value)}
                maxLength={6}
                required
              />
              <Button fullWidth onClick={handleVerifyOTP} loading={loading}>
                Verify OTP
              </Button>
              <Button
                variant="subtle"
                fullWidth
                onClick={() => {
                  setStep('phone');
                  setOtp('');
                }}
              >
                Change Phone Number
              </Button>
            </>
          )}
        </Stack>
      </Paper>
    </Container>
  );
}


