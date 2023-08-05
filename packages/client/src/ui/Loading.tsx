import React, { useMemo, useState } from "react";

interface LoadingProps {
  isLoading: boolean;
}

const Loading = ({ isLoading }): LoadingProps => {
  return <div className="loading"></div>;
};

export default Loading;
