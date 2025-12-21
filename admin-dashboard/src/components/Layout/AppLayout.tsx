'use client';

import { useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import {
  AppShell,
  Navbar,
  Header,
  Group,
  Button,
  Text,
  NavLink,
  Burger,
  Menu,
  Avatar,
} from '@mantine/core';
import {
  IconDashboard,
  IconBuildingStore,
  IconCalendar,
  IconCurrencyDollar,
  IconLogout,
  IconUser,
} from '@tabler/icons-react';
import { useDisclosure } from '@mantine/hooks';

interface AppLayoutProps {
  children: React.ReactNode;
}

const navItems = [
  { label: 'Dashboard', icon: IconDashboard, href: '/dashboard' },
  { label: 'Venues', icon: IconBuildingStore, href: '/dashboard/venues' },
  { label: 'Bookings', icon: IconCalendar, href: '/dashboard/bookings' },
  { label: 'Payouts', icon: IconCurrencyDollar, href: '/dashboard/payouts' },
];

export function AppLayout({ children }: AppLayoutProps) {
  const router = useRouter();
  const pathname = usePathname();
  const [opened, { toggle }] = useDisclosure();

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    router.push('/login');
  };

  return (
    <AppShell
      header={{ height: 60 }}
      navbar={{
        width: 250,
        breakpoint: 'sm',
        collapsed: { mobile: !opened },
      }}
      padding="md"
    >
      <AppShell.Header>
        <Group h="100%" px="md" justify="space-between">
          <Group>
            <Burger opened={opened} onClick={toggle} hiddenFrom="sm" size="sm" />
            <Text fw={700} size="lg">
              Indoor Games Admin
            </Text>
          </Group>
          <Menu shadow="md" width={200}>
            <Menu.Target>
              <Button variant="subtle" leftSection={<IconUser size={16} />}>
                Admin
              </Button>
            </Menu.Target>
            <Menu.Dropdown>
              <Menu.Item leftSection={<IconLogout size={16} />} onClick={handleLogout}>
                Logout
              </Menu.Item>
            </Menu.Dropdown>
          </Menu>
        </Group>
      </AppShell.Header>

      <AppShell.Navbar p="md">
        {navItems.map((item) => (
          <NavLink
            key={item.href}
            href={item.href}
            label={item.label}
            leftSection={<item.icon size={20} />}
            active={pathname === item.href}
            onClick={(e) => {
              e.preventDefault();
              router.push(item.href);
            }}
            mb="xs"
          />
        ))}
      </AppShell.Navbar>

      <AppShell.Main>{children}</AppShell.Main>
    </AppShell>
  );
}


