import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private supabaseService: SupabaseService) {}

  async findOne(id: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: user, error } = await supabase
      .from('users')
      .select('id, phone, name, role, created_at')
      .eq('id', id)
      .single();

    if (!user || error) {
      throw new NotFoundException('User not found');
    }

    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      role: user.role,
      createdAt: user.created_at,
    };
  }

  async update(id: string, dto: UpdateUserDto) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: user, error } = await supabase
      .from('users')
      .update(dto)
      .eq('id', id)
      .select('id, phone, name, role, created_at')
      .single();

    if (!user || error) {
      throw new NotFoundException('User not found');
    }

    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      role: user.role,
      createdAt: user.created_at,
    };
  }
}

