const types = @import("types.zig");
const StackSlot = types.StackSlot;
const ExternalCallParamLayout = types.ExternalCallParamLayout;

pub fn getParamLayout(params: [*]StackSlot) *const ExternalCallParamLayout {   
    return @ptrCast(@alignCast((params - 4)[0].ptr));
}

pub fn getParam(params: [*]StackSlot, index: c_int) ?*StackSlot {

    const layout = getParamLayout(params);
    if(index < 0 or index >= layout.num_params - layout.num_result_params - 1) {
        return null;
    }

    const slot_offset: usize = @intCast(index + 1);
    const first_slot_index = layout.firstSlotIndex();
    const slot_index: usize = @intCast((first_slot_index[slot_offset]));
    return &params[slot_index];
}

pub fn getResult(params: [*]StackSlot, result: *StackSlot) *StackSlot {

    const layout = getParamLayout(params);
    if(layout.num_result_params == 1) {
        const slot_offset: usize = @intCast(layout.num_params - 1);
        const first_slot_index = layout.firstSlotIndex();
        const slot_index: usize = @intCast((first_slot_index[slot_offset]));
        result.ptr = params[slot_index].ptr;
    }

    return result;
}