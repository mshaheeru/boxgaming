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
  Select,
  Stack,
} from '@mantine/core';
import { IconCheck, IconX, IconEye } from '@tabler/icons-react';
import { notifications } from '@mantine/notifications';
import api from '@/lib/api';

interface Venue {
  id: string;
  name: string;
  city: string;
  status: 'pending' | 'active' | 'suspended';
  owner: {
    name: string;
    phone: string;
  };
  createdAt: string;
}

export default function VenuesPage() {
  const [venues, setVenues] = useState<Venue[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedVenue, setSelectedVenue] = useState<Venue | null>(null);
  const [viewModalOpened, setViewModalOpened] = useState(false);

  useEffect(() => {
    fetchVenues();
  }, []);

  const fetchVenues = async () => {
    try {
      const response = await api.get('/venues?limit=100');
      setVenues(response.data.data || []);
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to fetch venues',
        color: 'red',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (venueId: string) => {
    try {
      // Note: You'll need to add an admin endpoint for venue approval
      await api.put(`/venues/${venueId}/approve`);
      notifications.show({
        title: 'Success',
        message: 'Venue approved successfully',
        color: 'green',
      });
      fetchVenues();
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to approve venue',
        color: 'red',
      });
    }
  };

  const handleSuspend = async (venueId: string) => {
    try {
      await api.put(`/venues/${venueId}/suspend`);
      notifications.show({
        title: 'Success',
        message: 'Venue suspended successfully',
        color: 'yellow',
      });
      fetchVenues();
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to suspend venue',
        color: 'red',
      });
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'green';
      case 'pending':
        return 'yellow';
      case 'suspended':
        return 'red';
      default:
        return 'gray';
    }
  };

  const rows = venues.map((venue) => (
    <Table.Tr key={venue.id}>
      <Table.Td>{venue.name}</Table.Td>
      <Table.Td>{venue.city || 'N/A'}</Table.Td>
      <Table.Td>{venue.owner?.name || 'N/A'}</Table.Td>
      <Table.Td>
        <Badge color={getStatusColor(venue.status)}>{venue.status}</Badge>
      </Table.Td>
      <Table.Td>{new Date(venue.createdAt).toLocaleDateString()}</Table.Td>
      <Table.Td>
        <Group gap="xs">
          <ActionIcon
            variant="subtle"
            color="blue"
            onClick={() => {
              setSelectedVenue(venue);
              setViewModalOpened(true);
            }}
          >
            <IconEye size={16} />
          </ActionIcon>
          {venue.status === 'pending' && (
            <ActionIcon
              variant="subtle"
              color="green"
              onClick={() => handleApprove(venue.id)}
            >
              <IconCheck size={16} />
            </ActionIcon>
          )}
          {venue.status === 'active' && (
            <ActionIcon
              variant="subtle"
              color="red"
              onClick={() => handleSuspend(venue.id)}
            >
              <IconX size={16} />
            </ActionIcon>
          )}
        </Group>
      </Table.Td>
    </Table.Tr>
  ));

  return (
    <Container size="xl" py="xl">
      <Group justify="space-between" mb="xl">
        <Title order={1}>Venues</Title>
        <Button onClick={fetchVenues}>Refresh</Button>
      </Group>

      <Table.ScrollContainer minWidth={800}>
        <Table striped highlightOnHover>
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Name</Table.Th>
              <Table.Th>City</Table.Th>
              <Table.Th>Owner</Table.Th>
              <Table.Th>Status</Table.Th>
              <Table.Th>Created</Table.Th>
              <Table.Th>Actions</Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {loading ? (
              <Table.Tr>
                <Table.Td colSpan={6} ta="center">
                  Loading...
                </Table.Td>
              </Table.Tr>
            ) : rows.length === 0 ? (
              <Table.Tr>
                <Table.Td colSpan={6} ta="center">
                  No venues found
                </Table.Td>
              </Table.Tr>
            ) : (
              rows
            )}
          </Table.Tbody>
        </Table>
      </Table.ScrollContainer>

      <Modal
        opened={viewModalOpened}
        onClose={() => setViewModalOpened(false)}
        title="Venue Details"
        size="lg"
      >
        {selectedVenue && (
          <Stack gap="md">
            <TextInput label="Name" value={selectedVenue.name} readOnly />
            <TextInput label="City" value={selectedVenue.city || 'N/A'} readOnly />
            <TextInput
              label="Owner Name"
              value={selectedVenue.owner?.name || 'N/A'}
              readOnly
            />
            <TextInput
              label="Owner Phone"
              value={selectedVenue.owner?.phone || 'N/A'}
              readOnly
            />
            <Select
              label="Status"
              value={selectedVenue.status}
              data={[
                { value: 'pending', label: 'Pending' },
                { value: 'active', label: 'Active' },
                { value: 'suspended', label: 'Suspended' },
              ]}
              readOnly
            />
          </Stack>
        )}
      </Modal>
    </Container>
  );
}




