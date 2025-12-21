'use client';

import { useEffect, useState } from 'react';
import {
  Container,
  Title,
  Table,
  Button,
  Group,
  Badge,
  ActionIcon,
  Modal,
  TextInput,
  Stack,
} from '@mantine/core';
import { IconCheck } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import api from '@/lib/api';
import dayjs from 'dayjs';

interface Payout {
  id: string;
  owner: {
    name: string;
    phone: string;
  };
  periodStart: string;
  periodEnd: string;
  grossAmount: number;
  commissionAmount: number;
  netAmount: number;
  status: 'pending' | 'paid';
  paidAt: string | null;
  bankReference: string | null;
}

export default function PayoutsPage() {
  const [payouts, setPayouts] = useState<Payout[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPayout, setSelectedPayout] = useState<Payout | null>(null);
  const [markPaidModalOpened, setMarkPaidModalOpened] = useState(false);
  const [bankReference, setBankReference] = useState('');

  useEffect(() => {
    fetchPayouts();
  }, []);

  const fetchPayouts = async () => {
    try {
      // Note: You'll need to add an admin endpoint to get all payouts
      const response = await api.get('/payouts?limit=100');
      setPayouts(response.data.data || response.data || []);
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to fetch payouts',
        color: 'red',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleMarkPaid = async () => {
    if (!selectedPayout || !bankReference) {
      notifications.show({
        title: 'Error',
        message: 'Please enter bank reference',
        color: 'red',
      });
      return;
    }

    try {
      await api.put(`/payouts/${selectedPayout.id}/mark-paid`, {
        bankReference,
      });
      notifications.show({
        title: 'Success',
        message: 'Payout marked as paid',
        color: 'green',
      });
      setMarkPaidModalOpened(false);
      setBankReference('');
      setSelectedPayout(null);
      fetchPayouts();
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to mark payout as paid',
        color: 'red',
      });
    }
  };

  const rows = payouts.map((payout) => (
    <Table.Tr key={payout.id}>
      <Table.Td>{payout.owner.name || payout.owner.phone}</Table.Td>
      <Table.Td>
        {dayjs(payout.periodStart).format('MMM DD')} -{' '}
        {dayjs(payout.periodEnd).format('MMM DD, YYYY')}
      </Table.Td>
      <Table.Td>Rs. {Number(payout.grossAmount).toLocaleString()}</Table.Td>
      <Table.Td>Rs. {Number(payout.commissionAmount).toLocaleString()}</Table.Td>
      <Table.Td>Rs. {Number(payout.netAmount).toLocaleString()}</Table.Td>
      <Table.Td>
        <Badge color={payout.status === 'paid' ? 'green' : 'yellow'}>
          {payout.status}
        </Badge>
      </Table.Td>
      <Table.Td>{payout.bankReference || 'N/A'}</Table.Td>
      <Table.Td>
        {payout.status === 'pending' && (
          <ActionIcon
            variant="subtle"
            color="green"
            onClick={() => {
              setSelectedPayout(payout);
              setMarkPaidModalOpened(true);
            }}
          >
            <IconCheck size={16} />
          </ActionIcon>
        )}
      </Table.Td>
    </Table.Tr>
  ));

  return (
    <Container size="xl" py="xl">
      <Group justify="space-between" mb="xl">
        <Title order={1}>Payouts</Title>
        <Button onClick={fetchPayouts}>Refresh</Button>
      </Group>

      <Table.ScrollContainer minWidth={1000}>
        <Table striped highlightOnHover>
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Owner</Table.Th>
              <Table.Th>Period</Table.Th>
              <Table.Th>Gross Amount</Table.Th>
              <Table.Th>Commission</Table.Th>
              <Table.Th>Net Amount</Table.Th>
              <Table.Th>Status</Table.Th>
              <Table.Th>Bank Reference</Table.Th>
              <Table.Th>Actions</Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {loading ? (
              <Table.Tr>
                <Table.Td colSpan={8} ta="center">
                  Loading...
                </Table.Td>
              </Table.Tr>
            ) : rows.length === 0 ? (
              <Table.Tr>
                <Table.Td colSpan={8} ta="center">
                  No payouts found
                </Table.Td>
              </Table.Tr>
            ) : (
              rows
            )}
          </Table.Tbody>
        </Table>
      </Table.ScrollContainer>

      <Modal
        opened={markPaidModalOpened}
        onClose={() => {
          setMarkPaidModalOpened(false);
          setBankReference('');
          setSelectedPayout(null);
        }}
        title="Mark Payout as Paid"
      >
        <Stack gap="md">
          <TextInput
            label="Bank Reference"
            placeholder="Enter bank transaction reference"
            value={bankReference}
            onChange={(e) => setBankReference(e.target.value)}
            required
          />
          {selectedPayout && (
            <Group justify="space-between">
              <Text size="sm" c="dimmed">
                Amount: Rs. {Number(selectedPayout.netAmount).toLocaleString()}
              </Text>
            </Group>
          )}
          <Group justify="flex-end" mt="md">
            <Button
              variant="subtle"
              onClick={() => {
                setMarkPaidModalOpened(false);
                setBankReference('');
                setSelectedPayout(null);
              }}
            >
              Cancel
            </Button>
            <Button onClick={handleMarkPaid}>Mark as Paid</Button>
          </Group>
        </Stack>
      </Modal>
    </Container>
  );
}




