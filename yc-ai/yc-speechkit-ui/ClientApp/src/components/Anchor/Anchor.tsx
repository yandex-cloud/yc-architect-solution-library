import React from 'react';
import block from 'bem-cn-lite';
import { ClassNameProps } from '@yandex-data-ui/cloud-components';

import './Anchor.scss';

const b = block('Anchor');

interface AnchorProps extends ClassNameProps {
    id: string;
}

const Anchor: React.FC<AnchorProps> = ({ id, className }) => (
    <div id={id} className={b(null, className)}></div>
);

export default Anchor;