import React, { useEffect, useState, useContext } from "react";

export const StickyStateContext = React.createContext({});

export default (defaultValue, key) => {
  const { state, setState } = useContext(StickyStateContext);

  const value = (state || {})[key] || defaultValue;
  const setValue = (value) => setState((state) => ({ ...state, [key]: value }));

  return [value, setValue];
};

export const StickyStateStore = ({
  key = "pharmtraceEricaStickyState",
  children,
}) => {
  const [state, setState] = useState(() => {
    const stickyState = window.localStorage.getItem(key);

    return stickyState !== null ? JSON.parse(stickyState) : {};
  });
  const stateDump = JSON.stringify(state);

  useEffect(() => {
    window.localStorage.setItem(key, stateDump);
  }, [key, stateDump]);

  return (
    <StickyStateContext.Provider value={{ state, setState }}>
      {children}
    </StickyStateContext.Provider>
  );
};
