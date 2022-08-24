import React from 'react';
import PropTypes from 'prop-types';
import block from 'bem-cn-lite';
/*import { toDataAttrs } from 'utils';*/

import Anchor from '../Anchor/Anchor.tsx';

import './Section.scss';

const b = block('Section');

const propTypes = {
    children: PropTypes.node.isRequired,
    id: PropTypes.string,
    className: PropTypes.string,
    dataAttrs: PropTypes.object,
    anchorClass: PropTypes.string,
};

const defaultProps = {
    heading: false,
    false: false,
};

export default function Section({ children, id, className, dataAttrs, anchorClass }) {
    return (
        <section className={b(null, className)}> 
            {id && <Anchor id={id} className={b('anchor', anchorClass)} />}
            <div className={b('content')}>{children}</div>
        </section>
    );
}

Section.propTypes = propTypes;
Section.defaultProps = defaultProps;