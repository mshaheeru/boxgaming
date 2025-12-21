'use client';

import { useEffect, useState } from 'react';
import { Container, Title, Grid, Card, Text, Group, Badge, Stack } from '@mantine/core';
import {
  IconBuildingStore,
  IconCalendar,
  IconCurrencyDollar,
  IconUsers,
} from '@tabler/icons-react';
import api from '@/lib/api';

interface DashboardStats {
  totalVenues: number;
  pendingVenues: number;
  totalBookings: number;
  todayBookings: number;
  totalRevenue: number;
  pendingPayouts: number;
  totalCustomers: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      // Fetch venues
      const venuesRes = await api.get('/venues?limit=1');
      const totalVenues = venuesRes.data.meta?.total || 0;
      const pendingVenues = venuesRes.data.data?.filter(
        (v: any) => v.status === 'pending'
      ).length || 0;

      // Fetch bookings
      // Note: You'll need to add an admin endpoint to get all bookings
      const bookingsRes = await api.get('/bookings?limit=1');
      const totalBookings = bookingsRes.data.meta?.total || 0;

      setStats({
        totalVenues,
        pendingVenues,
        totalBookings,
        todayBookings: 0, // TODO: Calculate from bookings
        totalRevenue: 0, // TODO: Calculate from payouts
        pendingPayouts: 0, // TODO: Fetch from payouts
        totalCustomers: 0, // TODO: Fetch from users
      });
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      title: 'Total Venues',
      value: stats?.totalVenues || 0,
      icon: IconBuildingStore,
      color: 'blue',
      subtitle: `${stats?.pendingVenues || 0} pending approval`,
    },
    {
      title: 'Total Bookings',
      value: stats?.totalBookings || 0,
      icon: IconCalendar,
      color: 'green',
      subtitle: `${stats?.todayBookings || 0} today`,
    },
    {
      title: 'Total Revenue',
      value: `Rs. ${(stats?.totalRevenue || 0).toLocaleString()}`,
      icon: IconCurrencyDollar,
      color: 'yellow',
      subtitle: `${stats?.pendingPayouts || 0} pending payouts`,
    },
    {
      title: 'Total Customers',
      value: stats?.totalCustomers || 0,
      icon: IconUsers,
      color: 'violet',
      subtitle: 'Registered users',
    },
  ];

  return (
    <Container size="xl" py="xl">
      <Title order={1} mb="xl">
        Dashboard
      </Title>

      <Grid>
        {statCards.map((card) => (
          <Grid.Col key={card.title} span={{ base: 12, sm: 6, md: 3 }}>
            <Card shadow="sm" padding="lg" radius="md" withBorder>
              <Group justify="space-between" mb="xs">
                <card.icon size={24} color={card.color} />
                <Badge color={card.color} variant="light">
                  {card.title}
                </Badge>
              </Group>
              <Text fw={700} size="xl">
                {card.value}
              </Text>
              <Text size="sm" c="dimmed">
                {card.subtitle}
              </Text>
            </Card>
          </Grid.Col>
        ))}
      </Grid>
    </Container>
  );
}




