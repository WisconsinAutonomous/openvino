// Copyright (C) 2018-2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0
//

#include "intel_gpu/plugin/program.hpp"
#include "intel_gpu/plugin/common_utils.hpp"

#include "ngraph/op/reverse_sequence.hpp"

#include "intel_gpu/primitives/reverse_sequence.hpp"

namespace ov {
namespace intel_gpu {

static void CreateReverseSequenceOp(Program& p, const std::shared_ptr<ngraph::op::v0::ReverseSequence>& op) {
    validate_inputs_count(op, {2});
    auto inputs = p.GetInputInfo(op);
    std::string layerName = layer_type_name_ID(op);

    size_t batch_axis = op->get_batch_axis();
    size_t seq_axis = op->get_sequence_axis();
    auto reverseSequencePrim = cldnn::reverse_sequence(layerName,
                                                       inputs[0],
                                                       inputs[1],
                                                       seq_axis,
                                                       batch_axis);

    p.add_primitive(*op, reverseSequencePrim);
}

REGISTER_FACTORY_IMPL(v0, ReverseSequence);

}  // namespace intel_gpu
}  // namespace ov
