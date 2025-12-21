'use client';

import { useEffect, useState } from 'react';
import {
  Container,
  Title,
  Table,
  Button,
  Group,
  Badge,
  TextInput,
  Select,
  Stack,
} from '@mantine/core';
import { DatePickerInput } from '@mantine/dates';
import { notifications } from '@mantine/notifications';
import api from '@/lib/api';
import dayjs from 'dayjs';

interface Booking {
  id: string;
  bookingCode: string;
  customer: {
    name: string;
    phone: string;
  };
  ground: {
    name: string;
    venue: {
      name: string;
    };
  };
  bookingDate: string;
  startTime: string;
  durationHours: number;
  price: number;
  status: string;
  createdAt: string;
}

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [dateFilter, setDateFilter] = useState<Date | null>(null);
  const [statusFilter, setStatusFilter] = useState<string | null>(null);

  useEffect(() => {
    fetchBookings();
  }, [dateFilter, statusFilter]);

  const fetchBookings = async () => {
    try {
      // Note: You'll need to add an admin endpoint to get all bookings
      const response = await api.get('/bookings?limit=100');
      let data = response.data.data || response.data || [];

      // Apply filters
      if (dateFilter) {
        data = data.filter((b: Booking) =>
          dayjs(b.bookingDate).isSame(dayjs(dateFilter), 'day')
        );
      }
      if (statusFilter) {
        data = data.filter((b: Booking) => b.status === statusFilter);
      }

      setBookings(data);
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to fetch bookings',
        color: 'red',
      });
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed':
        return 'blue';
      case 'started':
        return 'yellow';
      case 'completed':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'gray';
    }
  };

  const rows = bookings.map((booking) => (
    <Table.Tr key={booking.id}>
      <Table.Td>{booking.bookingCode}</Table.Td>
      <Table.Td>{booking.ground.venue.name}</Table.Td>
      <Table.Td>{booking.ground.name}</Table.Td>
      <Table.Td>{booking.customer.name || booking.customer.phone}</Table.Td>
      <Table.Td>{dayjs(booking.bookingDate).format('MMM DD, YYYY')}</Table.Td>
      <Table.Td>{booking.startTime}</Table.Td>
      <Table.Td>{booking.durationHours}hrs</Table.Td>
      <Table.Td>Rs. {Number(booking.price).toLocaleString()}</Table.Td>
      <Table.Td>
        <Badge color={getStatusColor(booking.status)}>{booking.status}</Badge>
      </Table.Td>
    </Table.Tr>
  ));

  return (
    <Container size="xl" py="xl">
      <Group justify="space-between" mb="xl">
        <Title order={1}>Bookings</Title>
        <Button onClick={fetchBookings}>Refresh</Button>
      </Group>

      <Stack gap="md" mb="xl">
        <Group>
          <DatePickerInput
            label="Filter by Date"
            placeholder="Select date"
            value={dateFilter}
            onChange={setDateFilter}
            clearable
          />
          <Select
            label="Filter by Status"
            placeholder="All statuses"
            value={statusFilter}
            onChange={setStatusFilter}
            data={[
              { value: 'confirmed', label: 'Confirmed' },
              { value: 'started', label: 'Started' },
              { value: 'completed', label: 'Completed' },
              { value: 'cancelled', label: 'Cancelled' },
            ]}
            clearable
          />
        </Group>
      </Stack>

      <Table.ScrollContainer minWidth={1000}>
        <Table striped highlightOnHover>
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Code</Table.Th>
              <Table.Th>Venue</Table.Th>
              <Table.Th>Ground</Table.Th>
              <Table.Th>Customer</Table.Th>
              <Table.Th>Date</Table.Th>
              <Table.Th>Time</Table.Th>
              <Table.Th>Duration</Table.Th>
              <Table.Th>Price</Table.Th>
              <Table.Th>Status</Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {loading ? (
              <Table.Tr>
                <Table.Td colSpan={9} ta="center">
                  Loading...
                </Table.Td>
              </Table.Tr>
            ) : rows.length === 0 ? (
              <Table.Tr>
                <Table.Td colSpan={9} ta="center">
                  No bookings found
                </Table.Td>
              </Table.Tr>
            ) : (
              rows
            )}
          </Table.Tbody>
        </Table>
      </Table.ScrollContainer>
    </Container>
  );
}




